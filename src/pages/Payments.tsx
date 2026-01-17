import { useEffect, useState } from 'react';
import { Eye } from 'lucide-react';
import { paymentsApi, type Payment } from '../lib/api';
import Modal from '../components/Modal';
import Badge from '../components/Badge';

export default function Payments() {
  const [payments, setPayments] = useState<Payment[]>([]);
  const [loading, setLoading] = useState(true);
  const [viewModalOpen, setViewModalOpen] = useState(false);
  const [selectedPayment, setSelectedPayment] = useState<Payment | null>(null);

  useEffect(() => {
    loadPayments();
  }, []);

  const loadPayments = async () => {
    try {
      const data = await paymentsApi.getAll();
      setPayments(data);
    } catch (error) {
      console.error('Error loading payments:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleViewDetails = (payment: Payment) => {
    setSelectedPayment(payment);
    setViewModalOpen(true);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const getStatusVariant = (status: string): 'success' | 'error' | 'warning' => {
    switch (status) {
      case 'success':
        return 'success';
      case 'failed':
        return 'error';
      case 'pending':
        return 'warning';
      default:
        return 'warning';
    }
  };

  const formatMethod = (method: string | null) => {
    if (!method) return 'N/A';
    return method
      .split('_')
      .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
      .join(' ');
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">Loading payments...</div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Payments</h1>
        <p className="text-gray-600 mt-1">View all payment transactions (Read-only)</p>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="text-left px-6 py-4 text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Transaction ID
                </th>
                <th className="text-left px-6 py-4 text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Date
                </th>
                <th className="text-left px-6 py-4 text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Amount
                </th>
                <th className="text-left px-6 py-4 text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Status
                </th>
                <th className="text-left px-6 py-4 text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Method
                </th>
                <th className="text-right px-6 py-4 text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {payments.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center text-gray-500">
                    No payments found.
                  </td>
                </tr>
              ) : (
                payments.map((payment) => (
                  <tr key={payment.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4">
                      <p className="text-sm font-mono text-gray-700">{payment.transaction_id}</p>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">
                      {formatDate(payment.created_at)}
                    </td>
                    <td className="px-6 py-4">
                      <span className="text-sm font-bold text-gray-900">
                        {payment.amount.toFixed(2)} {payment.currency}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <Badge variant={getStatusVariant(payment.status)}>
                        {payment.status.charAt(0).toUpperCase() + payment.status.slice(1)}
                      </Badge>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-700">
                      {formatMethod(payment.method)}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center justify-end">
                        <button
                          onClick={() => handleViewDetails(payment)}
                          className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                          title="View Details"
                        >
                          <Eye className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      <Modal
        isOpen={viewModalOpen}
        onClose={() => setViewModalOpen(false)}
        title="Payment Details"
        size="sm"
      >
        {selectedPayment && (
          <div className="space-y-6">
            <div>
              <h3 className="text-sm font-semibold text-gray-700 mb-2">Transaction ID</h3>
              <p className="text-gray-900 font-mono">{selectedPayment.transaction_id || 'N/A'}</p>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <h3 className="text-sm font-semibold text-gray-700 mb-2">Amount</h3>
                <p className="text-2xl font-bold text-gray-900">
                  {selectedPayment.amount.toFixed(2)} <span className="text-lg">{selectedPayment.currency}</span>
                </p>
              </div>
              <div>
                <h3 className="text-sm font-semibold text-gray-700 mb-2">Status</h3>
                <Badge variant={getStatusVariant(selectedPayment.status)}>
                  {selectedPayment.status.charAt(0).toUpperCase() + selectedPayment.status.slice(1)}
                </Badge>
              </div>
            </div>

            <div>
              <h3 className="text-sm font-semibold text-gray-700 mb-2">Payment Method</h3>
              <p className="text-gray-900">{formatMethod(selectedPayment.method)}</p>
            </div>

            <div>
              <h3 className="text-sm font-semibold text-gray-700 mb-2">Date & Time</h3>
              <p className="text-gray-900">{formatDate(selectedPayment.created_at)}</p>
            </div>

            <div className="pt-4 border-t border-gray-200">
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <span className="text-gray-600">Payment ID:</span>
                  <p className="font-mono text-gray-900 mt-1 text-xs">{selectedPayment.id}</p>
                </div>
                <div>
                  <span className="text-gray-600">Currency:</span>
                  <p className="font-medium text-gray-900 mt-1">{selectedPayment.currency}</p>
                </div>
              </div>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}
